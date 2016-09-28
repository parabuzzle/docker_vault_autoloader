# A simple library for working with Vault
#
# Author::    Michael Heijmans  (mailto:parabuzzle@gmail.com)
# Copyright:: Copyright (c) 2016 Michael Heijmans
# License::   MIT

require 'vault'
require 'yaml'

class VaultLoader
  attr_accessor :vault, :app_env, :address, :timeout

  def initialize(opts={})
    @app_env = opts[:environment] || ENV['APP_ENV'] || 'development'
    @timeout = opts[:timeout] 	  || 2
    @address = opts[:address]     || ENV['VAULT_ADDR']
    reconnect!
  end

  def connection
    vault = Vault::Client.new(address: address, timeout: 10)
    if ENV['VAULT_AUTH'] == 'github'
      vault.auth.github(ENV['VAULT_TOKEN'])
    end
    return vault
  end

  def sealed?
    vault.sys.seal_status.sealed?
  end

  def path(key)
    path = "secret/#{ app_env }/#{ key }"
  end

  def reconnect!
    @vault = connection
  end

  def unseal(key)
    vault.sys.unseal(key)
  end

  def seal!
    vault.sys.seal
  end

  def write(key, value)
    begin
      return "#{path(key)}=#{value}" if vault.logical.write(path(key), value: value)
    rescue Vault::HTTPConnectionError => e
      STDERR.puts "Error connecting to Vault at #{vault.address}\n"
      raise e
    end
  end

  def read(key)
    begin
      if var = vault.logical.read(path(key))
        var.data[:value]
      end
    rescue Vault::HTTPConnectionError => e
      STDERR.puts "Error connecting to Vault at #{vault.address}\n"
      raise e
    end
  end

  def delete(key)
    begin
      vault.logical.delete(path(key))
    rescue Vault::HTTPConnectionError => e
      STDERR.puts "Error connecting to Vault at #{vault.address}\n"
      raise e
    end
  end
end
