require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'])

$rooms = (1..5).map { |i| { id: i, name: "Room #{i}" } }
$message_id = 0

class User < Struct.new(:name)
  include Sinapse
  alias_method :to_param, :name
end

class Room < Struct.new(:id)
  include Sinapse::Publishable
  alias_method :to_param, :id
end

class Message
  def initialize(room_id, user_name, body)
    @data = {
      id: $message_id += 1,
      room_id: room_id,
      user_name: user_name,
      body: body
    }
  end

  def valid?
    @data[:room_id] && @data[:user_name] && @data[:body]
  end

  def publish
    room = Room.new(@data[:room_id])
    room.publish JSON.dump(@data)
  end
end

class ChatServer < Sinatra::Base
  configure do
    enable :protection
    enable :sessions
    enable :static

    set :views, File.expand_path('../views', __FILE__)
    set :public_folder, File.expand_path('../public', __FILE__)
  end

  configure :development do
    register Sinatra::Reloader
  end

  before do
    unless request.path_info =~ %r(^(?:/|/sign_in)$)
      redirect '/' unless session[:user_name]
    end
  end

  get '/' do
    if session[:user_name]
      redirect '/rooms'
    else
      erb :sign_in
    end
  end

  post '/sign_in' do
    if params[:user_name]
      user = User.new(params[:user_name].slice(0, 20))
      session[:user_name] = user.name
      session[:user_token] = user.sinapse.auth.reset
      redirect '/rooms'
    else
      erb :sign_in
    end
  end

  get '/rooms' do
    erb :rooms, locals: { rooms: $rooms }
  end

  get '/rooms/:id' do |id|
    erb :rooms, locals: { rooms: $rooms }
  end

  post '/rooms/:id/subscribe' do |id|
    user = User.new(session[:user_name])
    user.sinapse.add_channel Room.new(id)
    200
  end

  post '/publish' do
    data = JSON.parse(request.body.read)
    message = Message.new(data['room_id'], session[:user_name], data['body'])
    return 422 unless message.valid?
    message.publish
    200
  end
end
