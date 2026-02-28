# frozen_string_literal: true

require "jennifer"
require_relative "stanza"

class Session
	include Jennifer.rant(self) {
		jid { string }
		stanza derived_from(:jid) { |jid|
			Stanza.new(@store).generate(jid)
		}
	}

	def initialize(store)
		@store = store
	end
end
