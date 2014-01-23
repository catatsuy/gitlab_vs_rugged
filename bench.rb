require "benchmark"
require "rugged"
require "grit"
require "pp"

GIT_REPO = '../git'

logs = File.read('git_sha1.log').split("\n")

Benchmark.bm do |x|
  x.report do
    repo_rugged = Rugged::Repository.new(GIT_REPO)

    logs.each do |sha1|
      tree_rugged = repo_rugged.lookup(sha1)
      tree_rugged.message
    end
  end

  x.report do
    repo_grit   = Grit::Repo.new(GIT_REPO)

    logs.each do |sha1|
      head = repo_grit.commit(sha1)
      head.message
    end
  end
end
