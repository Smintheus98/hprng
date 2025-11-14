import std / [monotimes, times, math]

type TimeUnit* = enum
  ns, us, ms, sec = "s"

proc tounit[T: int|float](d: Duration; tunit: TimeUnit): T =
  when T is int:
    case tunit:
      of ns: d.inNanoseconds
      of us: d.inMicroseconds
      of ms: d.inMilliseconds
      of sec: d.inSeconds
  elif T is float:
    case tunit:
      of ns: d.inNanoseconds.float
      of us: d.inNanoseconds.float / (10^3).float
      of ms: d.inNanoseconds.float / (10^6).float
      of sec: d.inNanoseconds.float / (10^9).float


template measure*(title: string; body: untyped): untyped =
  let a = getMonoTime()
  body
  let b = getMonoTime()
  let tdiff = b - a
  echo ">> ", title, "  ", tdiff

template measure*(title: string; unit: TimeUnit; kind: typedesc[int|float]; body: untyped): untyped =
  let a = getMonoTime()
  body
  let b = getMonoTime()
  let tdiff = (b - a).tounit[:kind](unit)
  echo ">> ", title, "  ", tdiff, " ", $unit


when isMainModule:
  measure "test", us, float:
    var s = 0
    for i in 0..10:
      s += i
    echo s

