local status_ok, zk = pcall(require, "zk")
if not status_ok then
  return
end

zk.setup()
