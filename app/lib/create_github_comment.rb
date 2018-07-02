class CreateGithubComment
  attr_accessor :content

  GITHUB_ACTIONS = %w'created submitted'

  def self.call(content)
    self.new(content).call
  end

  def initialize(content)
    @content = content
  end

  def call
    case content['action']
    when 'created'
      create_created_comment
    when 'submitted'
      create_submitted_comment
    else
      false
    end
  end

  private

  def create_submitted_comment
    body = content['review']['body']
    html_url = content['review']['html_url']
    state = content['review']['state']
    author_name = content['review']['user']['login']
    pr_url = content['pull_request']['html_url']

    unless in_black_list?(author_name) || (state == 'commented' && body.blank?)
      GithubComment.create(
        body: body,
        html_url: html_url,
        author_name: author_name,
        pr_url: pr_url,
        state: state
      )
    end
  end

  def create_created_comment
    body = content['comment']['body']
    html_url = content['comment']['html_url']
    author_name = content['comment']['user']['login']
    pr_url = if content['issue'].present?
               content['issue']['pull_request']['html_url']
             else
               content['pull_request']['html_url']
             end

    if body.present? && !in_black_list?(author_name)
      GithubComment.create(body: body, html_url: html_url, author_name: author_name, pr_url: pr_url)
    end
  end

  def in_black_list?(github_user)
    ENV['BLACK_LIST_GITHUB_USER'].split(',').include?(github_user)
  end
end
