require 'spec_helper'

module NNCore
  describe "nn_device" do

    context "given an initialized library and" do

      context "given a valid device which forwards messages between two sockets" do
        def run_device
          @socket1 = LibNanomsg.nn_socket(AF_SP_RAW, NN_PAIR)
          @socket2 = LibNanomsg.nn_socket(AF_SP_RAW, NN_PAIR)
          LibNanomsg.nn_bind(@socket1, "inproc://some_endpoint")
          LibNanomsg.nn_bind(@socket2, "inproc://some_other_endpoint")

          LibNanomsg.nn_device(@socket1, @socket2)
        end

        after(:each) do
          LibNanomsg.nn_term
          @thread.join
          LibNanomsg.nn_close(@socket1)
          LibNanomsg.nn_close(@socket2)
          LibNanomsg.nn_close(@endpoint1)
          LibNanomsg.nn_close(@endpoint2)
        end

        it "passes a pair of messages between endpoints" do
          @thread = Thread.new do
            rc = run_device

            expect(rc).to eql(-1)
            expect(LibNanomsg.nn_errno).to eql(ETERM)
          end

          @endpoint1 = LibNanomsg.nn_socket(AF_SP, NN_PAIR)
          @endpoint2 = LibNanomsg.nn_socket(AF_SP, NN_PAIR)
          LibNanomsg.nn_connect(@endpoint1, "inproc://some_endpoint")
          LibNanomsg.nn_connect(@endpoint2, "inproc://some_other_endpoint")

          string = "nanomsg"
          string2 = "gsmonan"
          buffer = FFI::MemoryPointer.new(:pointer)

          LibNanomsg.nn_send(@endpoint1, string, string.size, 0)
          LibNanomsg.nn_recv(@endpoint2, buffer, NN_MSG, 0)
          expect(buffer.get_pointer(0).read_string_to_null).to eql(string)

          LibNanomsg.nn_send(@endpoint2, string2, string2.size, 0)
          LibNanomsg.nn_recv(@endpoint1, buffer, NN_MSG, 0)
          expect(buffer.get_pointer(0).read_string_to_null).to eql(string2)
        end

      end

    end
  end
end
