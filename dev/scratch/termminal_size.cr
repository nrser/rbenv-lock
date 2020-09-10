# require "c/sys/ioctl"

# @see https://unix.superglobalmegacorp.com/Net2/newsrc/sys/ioctl.h.html
module IOCtl  
  
  lib LibIOCtl
    @[Extern]
    struct WinSize
      ws_row : LibC::UShort		# rows, in characters
      ws_col : LibC::UShort		# columns, in characters
      ws_xpixel : LibC::UShort	# horizontal size, pixels
      ws_ypixel : LibC::UShort	# vertical size, pixels
    end

    fun ioctl(
      fd : LibC::Int,
      request : LibC::ULong,
      response : WinSize*
    ) : LibC::Int
  end
  
  IOCPARM_MASK = 0x1fff
  IOC_VOID = 0x20000000
  IOC_OUT = 0x40000000
  IOC_IN = 0x80000000
  IOC_INOUT = (IOC_IN | IOC_OUT)
  
  def self._IOC(
    inout : Int32,
    group : Char,
    num : Int32,
    len : Int32,
  ) : UInt64
    (inout | ((len & IOCPARM_MASK) << 16) | (group.ord << 8) | num).to_u64()
  end
  
  TIOCGWINSZ = _IOC( IOC_OUT, 't', 104, sizeof( LibIOCtl::WinSize ) )
  
  def self.winsize( io : IO::FileDescriptor = STDOUT ) : LibIOCtl::WinSize
    errno = LibIOCtl.ioctl(io.fd, TIOCGWINSZ, out winsize)
    return winsize if errno == 0
    raise "Failed to get winsize from ioctl, errno #{errno}"
  end
  
end

while true
  puts IOCtl.winsize()
  sleep 1
end
