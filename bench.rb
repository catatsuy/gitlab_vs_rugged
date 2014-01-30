require "benchmark"
require "rugged"
require "grit"
require "pp"

GIT_REPO = '../git'
Grit::Git.git_max_size = 5242880 * 4

logs = File.read('git_sha1.log').split("\n")

repo_rugged = Rugged::Repository.new(GIT_REPO)
repo_grit   = Grit::Repo.new(GIT_REPO)

# cf: http://docs.ruby-lang.org/ja/2.0.0/class/Benchmark.html
caption = sprintf("%10s" + "%11s" * 5 + "\n", "user", "system", "cu", "cs", "total", "real")
format  = "%10.6u %10.6y %10.6U %10.6Y %10.6t %10.6r\n"

Benchmark.benchmark(caption, 15, format) do |x|
  tmp1 = logs.clone
  tmp1.shift
  tmp2 = logs.clone
  tmp2.push
  sha1_pairs = tmp1.zip tmp2


  x.report("[rugged] diff") do
    sha1_pairs.each do |sha1_pair|
      repo_rugged.diff(sha1_pair[0], sha1_pair[1])
    end
  end

  x.report("[grit] diff") do
    sha1_pairs.each do |sha1_pair|
      begin
        repo_grit.diff(sha1_pair[0], sha1_pair[1])
      rescue Grit::Git::GitTimeout
        pp sha1_pair[0], sha1_pair[1]
      end
    end
  end

  x.report("[rugged] commit") do
    logs.each do |sha1|
      tree_rugged = repo_rugged.lookup(sha1)
      tree_rugged.message
    end
  end

  x.report("[grit] commit") do
    logs.each do |sha1|
      head_grit = repo_grit.commit(sha1)
      head_grit.message
    end
  end

  COMMITS_COUNT = 10

  x.report("[grit] commits") do
    commits = repo_grit.commits('1aeb10a14d5ecf5a10a4536b873c9feb244a7848', COMMITS_COUNT)
    commits
    10.times do
      commits = repo_grit.commits(commits.last.id, COMMITS_COUNT)
    end
  end

  commits_rugged = []

  x.report("[rugged] commits") do
    walker = Rugged::Walker.new(repo_rugged)
    walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
    walker.push('1aeb10a14d5ecf5a10a4536b873c9feb244a7848')
    walker.each do |c|
      commits_rugged.push c.oid
      if commits_rugged.size > 100
        break
      end
    end
  end

end
