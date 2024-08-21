import gleam/erlang
import gleam/float
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/result
import gleam/string
import gleam/string_builder

const example_bpm_changes = "0.000=139.148,4.000=139.490,100.000=128.571,101.000=111.111,102.000=111.111,103.000=113.924,104.000=116.883,105.000=116.883,106.000=120.000,107.000=123.288,108.000=123.288,109.000=126.761,110.000=126.761,111.000=130.435,112.000=132.353,113.000=134.328,114.000=136.364,115.000=136.364,116.000=140.625,117.000=138.462,118.000=136.364,119.000=134.328,120.000=130.435,121.000=130.435,122.000=126.761,123.000=121.622,124.000=118.421,125.000=121.622,126.000=125.000,127.000=130.435,128.000=134.328,129.000=138.462,130.000=140.625,131.000=147.541,132.000=150.000,133.000=139.508,213.000=163.636,214.000=169.811,215.000=180.000,216.000=187.500,217.000=187.500,218.000=195.652,219.000=200.000,220.000=204.545,221.000=209.302,222.000=214.286,223.000=225.000,224.000=225.000"

const example_stops = "100.000=1.387"

type StepManiaTimingPoint {
  StepManiaBpmChange(beat: Float, bpm: Float)
  StepManiaStop(beat: Float, duration: Float)
}

pub fn main() {
  let stepmania_timing_points =
    create_stepmania_timing_points(example_bpm_changes, example_stops)

  let osu_timing_points =
    create_osu_timing_points(stepmania_timing_points, 0.0, [])

  io.println(osu_timing_points |> string.join("\n"))
}

fn parse_stepmania_float_kv_list(
  input: String,
  map: fn(Float, Float) -> a,
) -> List(a) {
  input
  |> string.split(",")
  |> list.flat_map(fn(part) {
    case string.split(part, "=") {
      [key, value] -> {
        case float.parse(key), float.parse(value) {
          Ok(key), Ok(value) -> [map(key, value)]
          _, _ -> {
            io.println_error("Invalid BPM change: " <> part)
            []
          }
        }
      }
      _ -> {
        io.println_error("Invalid BPM change: " <> part)
        []
      }
    }
  })
}

fn create_stepmania_timing_points(
  bpm_changes_input: String,
  stops_input: String,
) -> List(StepManiaTimingPoint) {
  let bpm_changes =
    parse_stepmania_float_kv_list(bpm_changes_input, StepManiaBpmChange)

  let stops = parse_stepmania_float_kv_list(stops_input, StepManiaStop)

  bpm_changes
  |> list.append(stops)
  |> list.sort(by: fn(a, b) { float.compare(a.beat, b.beat) })
}

fn create_osu_timing_points(
  stepmania_timing_points: List(StepManiaTimingPoint),
  current_time: Float,
  result: List(String),
) -> List(String) {
  case stepmania_timing_points {
    [] -> []
    [current, ..rest] -> {
      case current {
        StepManiaBpmChange(beat:, bpm:) -> {
          let beat_duration = 60.0 /. bpm
          case rest {
            [] -> result |> list.reverse
            [next, ..] -> {
              let beats_to_next = next.beat -. beat
              let next_time = current_time +. beat_duration *. beats_to_next
              create_osu_timing_points(rest, next_time, [
                format_osu_timing_point(current_time, beat_duration),
                ..result
              ])
            }
          }
        }
        StepManiaStop(_, duration:) -> {
          create_osu_timing_points(rest, current_time +. duration, result)
        }
      }
    }
  }
}

fn format_osu_timing_point(time: Float, beat_duration: Float) -> String {
  float.to_string(time *. 1000.0)
  <> ","
  <> float.to_string(beat_duration *. 1000.0)
  <> ",4,0,0,50,1,0"
}
