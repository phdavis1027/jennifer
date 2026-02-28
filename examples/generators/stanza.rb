# frozen_string_literal: true

require "jennifer"

class Stanza
	include Jennifer.rant(self) { |jid|
		id { string }
		from { jid }
		body { string }
		redis_state derived_from(:id) { |id|
			@store["stanza-#{id}"] = true
		}, transient: true
	}

	def initialize(store)
		@store = store
	end
end
