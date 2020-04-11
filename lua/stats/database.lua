require("mysqloo")
include('db_config.lua') -- don't leak our password

--[[
    Helper function to get a connection to the database
    This is callback based, running the callback function when a connection is established
    This should (hopefully) be the most stable way to keep connected to a database
]]--
function STATS:GetConnection(callback)
    if !self.Database then
        -- Create the database connection
        self.Database = mysqloo.connect(STATS.DB_IP, STATS.DB_USERNAME, STATS.DB_PASSWORD, STATS.DB_DATABASE)
        self.Database:connect()
        
        function self.Database:onConnectionFailed()
            print('Statistics database connection failed.')
        end
    elseif self.Database:status() != mysqloo.DATABASE_CONNECTED then
        -- This shouldn't happen very frequently
        self.Database:connect()
        return self.Database
    else
        -- Everything is working smoothly
        return self.Database
    end
end

-- Immediately attempt a connection to the database
-- This should hopefully persist for as long as we need
STATS:GetConnection()