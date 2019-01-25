ExUnit.start()

Mox.defmock(Ironman.MockHttpClient, for: Ironman.Utils.HttpClient.Impl)
Mox.defmock(Ironman.MockIO, for: Ironman.Utils.IO.Impl)
Mox.defmock(Ironman.MockCmd, for: Ironman.Utils.Cmd.Impl)
