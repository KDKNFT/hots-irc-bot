require 'rubygems'
require 'cinch'
require 'cinch/commands'
require 'sqlite3'

module Hotsbot::Commands
  class Battletags
    include Cinch::Plugin
    include Cinch::Commands

    match 'getbt', method: :getbt
    command(
      :getbt,
      { username: :string },
      summary: 'Print the BattleTag for the entered name'
    )

    match 'addbt', method: :addbt
    command(
      :addbt,
      { battletag: :string, region: :string },
      summary: 'Saves your BattleTag'
    )

    command :removebt

    def initialize(bot, db=nil)
      super bot

      if db.nil?
        @db = SQLite3::Database.new File.dirname(__FILE__) + '/../../../hotsbot.db'
      else
        @db = db
      end

      @db.execute 'CREATE TABLE IF NOT EXISTS Battletags (nick text, battletag text, region text)'
    end

    def getbt(m, username=nil)
      if username.nil?
        m.user.send 'A IRC username is required, example: !getbt Username'
      else
        result = load_battletag(username)

        if result.empty?
          m.channel.send "No BattleTag found for #{username}"
        else
          battletag = result.first.first
          region = result.first[1]

          m.channel.send "#{username}'s BattleTag is [#{region}]#{battletag}"
        end
      end
    end

    def load_battletag(username)
      @db.execute('SELECT battletag, region FROM Battletags WHERE nick=? COLLATE NOCASE', [username])
    end

    def addbt(m, battletag=nil, region=nil)
      if bad_addbt_input(battletag, region)
        if !is_addbt_input_nil(battletag, region) and bad_addbt_input_format(battletag, region)
          m.channel.send 'Bad BattleTag format, example: !addbt Username#1234 EU'
        else
          m.channel.send 'A BattleTag and region are required, example: !addbt Username#1234 EU'
        end
      else
        result = load_battletag(m.user.nick)
        if result.empty?
          @db.execute('INSERT INTO Battletags VALUES (?, ?, ?)', [m.user.nick, battletag, region])
          m.channel.send 'BattleTag added'
        else
          @db.execute('UPDATE Battletags SET battletag = ?, region = ? WHERE nick = ?', [battletag, region, m.user.nick])
          m.channel.send 'BattleTag updated'
        end
      end
    end

    def bad_addbt_input(battletag, region)
      is_addbt_input_nil(battletag, region) or bad_addbt_input_format(battletag, region)
    end

    def is_addbt_input_nil(battletag, region)
      battletag.nil? or region.nil?
    end

    def bad_addbt_input_format(battletag, region)
      battletag !~ %r{^\w+[#]\d{4,5}$} or region !~ %r{[A-Z]{2}}
    end

    def removebt(m)
      @db.execute('DELETE FROM Battletags WHERE nick=?', [m.user.nick])

      m.channel.send 'BattleTag removed'
    end
  end
end
