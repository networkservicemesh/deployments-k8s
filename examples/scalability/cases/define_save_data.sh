#!/bin/bash

function saveData() {
  local name=$1
  local title=$2
  local name_replacement=$3
  local query=$4

  echo saving ${name}
  echo query: ${query}

  mkdir -p "${RESULT_DIR}" || return 1

  local test_time_start=$(date --date="${TEST_TIME_START}" -u +%s)
  local test_time_end=$(date --date="${TEST_TIME_END}" -u +%s)
  local test_time_end_relative=$((${test_time_end} - ${test_time_start}))

  styx --duration $(($(date -u +%s)-${test_time_start} + 5))s --prometheus "${PROM_URL}" "${query}" > "${RESULT_DIR}/${name}.csv" || return 2

  sed -E -i "${name_replacement}" "${RESULT_DIR}/${name}.csv"

  cat > "${RESULT_DIR}/${name}.gnu" <<EOF
set terminal pngcairo dashed size 1400,900
set output '${RESULT_DIR}/${name}.png'

set datafile separator ';'
stats "${RESULT_DIR}/${name}.csv" skip 1 nooutput

set title "${title}"
set grid
set xtics time format "%tM:%tS"
set xrange [0:${test_time_end_relative}]
set key center bmargin horizontal

set for [i=5:300:9] linetype i linecolor rgb "dark-orange"

EOF

  local i=1
  for event in ${EVENT_LIST}
  do
    event_text_var=EVENT_TEXT_${event}
    event_time_var=EVENT_TIME_${event}
    event_time_relative=$(($(date --date="${!event_time_var}" -u +%s) - ${test_time_start}))
    cat >> "${RESULT_DIR}/${name}.gnu" <<EOF
set arrow from ${event_time_relative}, graph 0 to ${event_time_relative}, graph 1 nohead linetype ${i} linewidth 2 dashtype 2
set label "${!event_text_var}" at ${event_time_relative}, graph 1 textcolor lt ${i} offset 1,-${i}

EOF
    i=$((${i} + 1))
  done

  cat >> "${RESULT_DIR}/${name}.gnu" <<EOF
plot for [col=2:STATS_columns] "${RESULT_DIR}/${name}.csv" using (\$1-${test_time_start}):col with lines linewidth 2 title columnheader
EOF

  gnuplot "${RESULT_DIR}/${name}.gnu" || return 3

  curl \
    --silent \
    --show-error \
    "${PROM_URL}/api/v1/query_range" \
    --data-urlencode "query=${query}" \
    --data-urlencode "start=${TEST_TIME_START}" \
    --data-urlencode "end=${TEST_TIME_END}" \
    --data-urlencode "step=1s" \
    >"${RESULT_DIR}/${name}.json" \
    || return 4

    echo ${name} saved successfully
}
