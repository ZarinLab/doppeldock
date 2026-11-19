# Prints the statement coverage (percent) of the doppeldock script's shell code,
# from bashcov's coverage/coverage.json, leaving out heredoc bodies (the Mac
# app's JavaScript, generated scripts and texts): bashcov marks those covered
# whenever the heredoc is written, although nothing in them runs as shell.
#
#   ruby tests/coverage_lines.rb doppeldock coverage/coverage.json
require "json"

script_path, json_path = ARGV
skip = {}
term = nil
File.readlines(script_path, encoding: "UTF-8").each_with_index do |line, i|
  if term
    if line.chomp == term
      term = nil
    else
      skip[i] = true
    end
  elsif line !~ /^\s*#/ && line =~ /<<-?['"]?([A-Za-z_]+)['"]?/
    term = Regexp.last_match(1)
  end
end

coverage = JSON.parse(File.read(json_path, encoding: "UTF-8"))["coverage"]
key = coverage.keys.find { |k| File.basename(k) == "doppeldock" } or abort("coverage: no data for doppeldock")
relevant = covered = 0
coverage[key]["lines"].each_with_index do |hits, i|
  next if hits.nil? || skip[i]

  relevant += 1
  covered += 1 if hits.positive?
end
warn "Shell statements covered: #{covered} of #{relevant} (heredoc text left out)"
puts (100.0 * covered / relevant).round(1)
