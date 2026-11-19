# Coverage settings for tests/coverage.sh (bashcov uses SimpleCov).
# Only the doppeldock script itself is measured.
SimpleCov.configure do
  coverage_dir "coverage"
  skip "/tests/"
  skip "/tools/"
  skip "/.github/"
  skip "/site/"
  skip "/docs/"
end
