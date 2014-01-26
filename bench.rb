require "benchmark"
require "rugged"
require "grit"
require "pp"

GIT_REPO = '../git'

logs = File.read('git_sha1.log').split("\n")

repo_rugged = Rugged::Repository.new(GIT_REPO)
repo_grit   = Grit::Repo.new(GIT_REPO)

Benchmark.bm do |x|
  tmp1 = logs.clone
  tmp1.shift
  tmp2 = logs.clone
  tmp2.push
  sha1_pairs = tmp1.zip tmp2


  x.report do
    sha1_pairs.each do |sha1_pair|
      repo_rugged.diff(sha1_pair[0], sha1_pair[1])
    end
  end

  x.report do
    sha1_pairs.each do |sha1_pair|
      begin
        repo_grit.diff(sha1_pair[0], sha1_pair[1])
      rescue
        pp sha1_pair[0], sha1_pair[1]
      end
    end
  end

  x.report do
    logs.each do |sha1|
      tree_rugged = repo_rugged.lookup(sha1)
      tree_rugged.message
    end
  end

  x.report do
    logs.each do |sha1|
      head_grit = repo_grit.commit(sha1)
      head_grit.message
    end
  end
end
