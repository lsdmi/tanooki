# frozen_string_literal: true

require 'test_helper'

class McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_two)
    @token, @secret = issue(@user, %w[chapters:read chapters:write chapters:publish images:write])
    @fiction = fictions(:eighteen)
    FictionScanlator.find_or_create_by!(fiction: @fiction, scanlator: scanlators(:two))
  end

  teardown do
    Rails.cache.delete(Api::Limits.counter_key(:create, @user, Date.current))
    Rails.cache.delete(Api::Limits::WRITES_CACHE_KEY)
  end

  test 'a missing token is unauthorized' do
    post '/mcp', params: rpc('tools/list'), as: :json

    assert_response :unauthorized
    assert_includes response.headers['WWW-Authenticate'], '/.well-known/oauth-protected-resource/mcp'
    assert_not_includes response.headers['WWW-Authenticate'].to_s, 'baka_'
  end

  test 'get and delete are not offered' do
    get '/mcp', headers: auth
    get_status = response.status
    delete '/mcp', headers: auth

    assert_equal 405, get_status
    assert_response :method_not_allowed
  end

  test 'whoami is read only and revert is destructive' do
    body = call('tools/list')
    tools = body.dig('result', 'tools')
    whoami = tools.find { |tool| tool['name'] == 'whoami' }
    revert = tools.find { |tool| tool['name'] == 'revert_chapter' }

    assert whoami.dig('annotations', 'readOnlyHint')
    assert revert.dig('annotations', 'destructiveHint')
    assert_equal @user.name, tool_json('whoami').dig('user', 'name')
  end

  test 'create_chapter is an mcp draft and a write is logged' do
    lines = []
    Rails.logger.stub(:info, ->(*args, **_kwargs) { lines << args.join }) do
      created = tool_json('create_chapter', fiction: @fiction.slug, number: 8801, content: 'Чернетка з абзацом.')
      @created = created
    end

    line = lines.grep(/\A\[API\]/).join

    assert_equal 'mcp', Chapter.find(@created['id']).created_via
    assert_match(/action=mcp#create chapter=#{@created['id']} status=200/, line)
    assert_not line.match?(/#{Regexp.escape(@secret)}|Чернетка/)
  end

  test 'a read tool is not logged' do
    lines = []
    Rails.logger.stub(:info, ->(*args, **_kwargs) { lines << args.join }) { tool_json('whoami') }

    assert_empty lines.grep(/\A\[API\]/)
  end

  test 'the write switch still serves whoami' do
    Api::Limits.stop_writes!
    tool_json('whoami')

    assert_response :success

    post '/mcp',
         params: rpc('tools/call', name: 'create_chapter', arguments: { fiction: 'eighteen', number: 1, content: 'x' }),
         headers: auth, as: :json

    assert_response :forbidden
    assert_equal 'writes_disabled', response.parsed_body.dig('error', 'code')
  end

  test 'another teams chapter is not found' do
    body = tool_json('get_chapter', chapter_id: chapters(:one).id)

    assert_equal 'not_found', body.dig('error', 'code')
  end

  test 'the formatting guide and a prompt are available' do
    guide = call('resources/read', uri: 'baka://formatting-guide')
    prompt = call(
      'prompts/get', name: 'proofread_range', arguments: { fiction: 'eighteen', from: '1', to: '2', issue: 'діалоги' }
    )
    text = guide.dig('result', 'contents', 0, 'text')

    assert_match(/edit_paragraphs/, text)
    assert_match(/get_chapters/, prompt.dig('result', 'messages', 0, 'content', 'text'))
  end

  private

  def issue(user, scopes)
    token = ApiToken.issue!(user:, name: 'Claude', scopes:)
    [token, token.secret]
  end

  def auth
    { 'Authorization' => "Bearer #{@secret}", 'Accept' => 'application/json, text/event-stream' }
  end

  def rpc(method, **params)
    { jsonrpc: '2.0', id: 1, method:, params: }
  end

  def call(method, **params)
    post '/mcp', params: rpc(method, **params), headers: auth, as: :json
    json_body(response.body)
  end

  def tool_json(name, **arguments)
    body = call('tools/call', name:, arguments:)
    text = body.dig('result', 'content', 0, 'text')
    text.present? ? JSON.parse(text) : body
  end

  def json_body(raw)
    json = raw.start_with?('{') ? raw : raw[/^data: (\{.*\})/m, 1]
    JSON.parse(json)
  end
end
