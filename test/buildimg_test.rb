#!/usr/bin/env ruby

require 'fileutils'
require 'tempfile'

require 'minitest'
require 'minitest/autorun'
require 'minitest/reporters'

ROOT = File.expand_path '../..', __FILE__

env = ENV.to_hash.update(
  # prevent real scripts from being called
  'PATH' => "#{ File.expand_path '../bin', __FILE__ }:#{ ENV['PATH'] }",
  # prevent image from being pushed
  'TRAVIS_PULL_REQUEST' => '..o__o..',
  # fake a Travis repository slug
  'TRAVIS_REPO_SLUG' => 'test/platform-mysql',
  # fake the propagated branch
  'TRAVIS_BRANCH' => 'development'
)
SERVICENAME = env['TRAVIS_REPO_SLUG'][/test\/(.+)/, 1].sub 'platform-', ''

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
    @tmpdir = Dir.mktmpdir "#{ SERVICENAME }-"
    env['DUMP_PATH'] = @tmpdir
  end
  after do
    FileUtils.remove_entry @tmpdir
  end

  it "should call test-image with REPONAME and TAGNAME" do
    Dir.chdir @tmpdir do
      target = File.join env['PATH'].split(':', 2).first, 'dump'
      dest   = File.join @tmpdir, 'test-image'
      FileUtils.symlink target, dest

      buildimg env

      dump_path = File.join @tmpdir, 'test-image.dump'
      argv = File.open(dump_path) { |f| Marshal.load f }

      argv.must_equal ['quay.io/experimentalplatform/%s:%s' % [
        SERVICENAME,
        env['TRAVIS_BRANCH']
      ] ]
    end
  end

  it 'aborts if test-image exists but is not executable' do
    Dir.chdir @tmpdir do
      File.open('test-image', 'w') { |f| f << 'exit 0' }
      buildimg(env).must_be_same_as false
    end
  end
  it 'aborts if test-image returns != 0' do
    Dir.chdir @tmpdir do
      File.open 'test-image', 'w' do |file|
        file << 'exit 1'
        FileUtils.chmod 0755, file.path
      end

      buildimg(env).must_be_same_as false
    end
  end

  it 'tags the build' do
    Dir.chdir @tmpdir do
      buildimg(env).must_be_same_as true

      docker_repository = "quay.io/experimentalplatform/#{ SERVICENAME }"
      docker_tag        = env['TRAVIS_BRANCH']
      docker_path       = "#{ docker_repository }:#{ docker_tag }"

      dump_path = File.join @tmpdir, 'docker.dump'
      argv = File.open(dump_path) { |f| Marshal.load f }
      argv.must_equal %W[ build -t #{ docker_path } . ]
    end
  end

end
