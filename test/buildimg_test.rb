#!/usr/bin/env ruby

require 'fileutils'
require 'tempfile'

require 'minitest'
require 'minitest/autorun'
require 'minitest/reporters'

ROOT = File.expand_path '../..', __FILE__

def load_env(path, base = {})
  unless File.exist? path
    # see .env.sample
    raise "Could not load #{ path }, file does not exist."
  end

  env = {}
  File.open(path) do |file|
    until file.eof?
      env.send '[]=', *file.gets.split('=').map(&:chomp)
    end
  end

  # prevent image from being pushed
  env['TRAVIS_PULL_REQUEST'] = 'TRUE'
  # fake a Travis repository slug
  env['TRAVIS_REPO_SLUG']    = "test/#{ env['GITHUB_REPO'][/\/(.+)$/, 1] }"
  # prevent real docker from being called
  env['PATH']                = "#{ File.expand_path '../bin', __FILE__ }:#{ base['PATH'] }"

  return base.merge(env)
end

env  = load_env File.join(ROOT, %w[ test .env ]), ENV.to_hash

REPO = Dir.mktmpdir
MiniTest.after_run { FileUtils.remove_entry REPO }

GITHUB_REPO = env.fetch 'GITHUB_REPO'
GITHUB_URL  = "git@github.com:#{ GITHUB_REPO }.git"

puts "Caching repository #{ GITHUB_URL }..."
system 'git', 'clone', '--recursive', '--quiet', GITHUB_URL, REPO

NAME = GITHUB_REPO[/\/(.+)$/, 1]

describe 'buildimg.sh' do

  def debug(*arguments)
    puts(*arguments) if $-d
  end

  def buildimg(env)
    IO.popen env, File.join(ROOT, 'buildimg.sh') do |io|
      io.each { |output| debug output }
    end
    return $?.success?
  end

  before do
    @tmpdir = Dir.mktmpdir "#{ NAME }-"
    env['DUMP_PATH'] = @tmpdir
    FileUtils.cp_r Dir["#{ REPO }/*"], @tmpdir
  end
  after do
    FileUtils.remove_entry @tmpdir
  end

  it "should call test-image with TAGNAME" do
    Dir.chdir @tmpdir do
      target = File.join env['PATH'].split(':', 2).first, 'dump'
      dest   = File.join @tmpdir, 'test-image'
      FileUtils.symlink target, dest

      buildimg env

      dump_path = File.join @tmpdir, 'test-image.dump'
      argv = File.open(dump_path) { |f| Marshal.load f }

      argv.must_equal ['quay.io/experimentalplatform/%s:%s' % [
        env['GITHUB_REPO'][/\/(.+)$/, 1],
        env['TRAVIS_BRANCH']
      ] ]
    end
  end

  it 'aborts if test-image exists but is not executable' do
    Dir.chdir @tmpdir do
      File.open('test-image', 'w') { |f| f << 'exit 0' }
      buildimg(env).must_equal false
    end
  end
  it 'aborts if test-image returns != 0' do
    Dir.chdir @tmpdir do
      File.open 'test-image', 'w' do |file|
        file << 'exit 1'
        FileUtils.chmod 0755, file.path
      end

      buildimg(env).must_equal false
    end
  end

  it 'tags the build' do
    Dir.chdir @tmpdir do
      buildimg(env).must_be_same_as true

      docker_repository = "quay.io/experimentalplatform/#{ NAME }"
      docker_tag        = env['TRAVIS_BRANCH']
      docker_path       = "#{ docker_repository }:#{ docker_tag }"

      dump_path = File.join @tmpdir, 'docker.dump'
      argv = File.open(dump_path) { |f| Marshal.load f }
      argv.must_equal %W[ build -t #{ docker_path } . ]
    end
  end

end
