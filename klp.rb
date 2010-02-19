# encoding: utf-8

require "rubygems"
require "sinatra"
require 'net/http'
require 'iconv'
require "klp_printer"

class InvalidURL < ArgumentError; end

get "/" do
  if params[:url] && params[:url].strip != ""
    doc = KLPPrinter.parse(params[:url]) rescue nil
    erb :print, :locals => {:doc => doc}
  else
    erb :index
  end
end
