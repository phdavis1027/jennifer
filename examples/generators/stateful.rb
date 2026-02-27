# frozen_string_literal: true

require "jennifer"

class Stateful
	include Jennifer.rant(self) {
		jid { string }
		registered { choose(true, false) }
		redis_state derived_from(:registered, :jid) { |registered, jid|
			@store["catapult_cred-#{jid}"] = true if registered
		}, transient: true
	}

	def initialize(store)
		@store = store
	end
end
