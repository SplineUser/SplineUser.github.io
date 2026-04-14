#!/usr/bin/env ruby
#
# Check for changed posts
# Gracefully skips git lookups when no .git directory is present
# (e.g. when the site was extracted from a zip rather than cloned).

require 'open3'

Jekyll::Hooks.register :posts, :post_init do |post|

  begin
    # Check we're inside a real git repo (cross-platform, suppresses stderr)
    git_root, _err, status = Open3.capture3(
      'git', '-C', File.dirname(post.path), 'rev-parse', '--show-toplevel'
    )
    next unless status.success? && !git_root.strip.empty?

    commit_num, _err, status = Open3.capture3(
      'git', 'rev-list', '--count', 'HEAD', post.path
    )
    next unless status.success?

    if commit_num.strip.to_i > 1
      lastmod_date, _err, status = Open3.capture3(
        'git', 'log', '-1', '--pretty=%ad', '--date=iso', post.path
      )
      post.data['last_modified_at'] = lastmod_date.strip if status.success? && !lastmod_date.strip.empty?
    end

  rescue Errno::ENOENT
    # git is not installed or not in PATH — skip silently
  end

end
