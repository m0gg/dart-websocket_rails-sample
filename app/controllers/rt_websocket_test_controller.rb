class RtWebsocketTestController < WebsocketRails::BaseController

  def new_client
    send_message :data, TestData.all.offset(1)
    EventMachine.defer proc { sleep 2 }, proc { send_message :push, TestData.all.limit(1), channel: :testdata }
  end

  def pull
    send_message :push, TestData.all, channel: :testdata
    trigger_success
  end
end
