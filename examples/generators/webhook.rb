# frozen_string_literal: true

require "jennifer"
require_relative "message"

class Webhook
	INBOUND_TYPES = ["message-received"]
	OUTBOUND_TYPES = ["message-delivered", "message-failed"]

	include Jennifer.rant(self) {
		time { iso8601 }
		type {
			choose(*(INBOUND_TYPES + OUTBOUND_TYPES))
		}
		direction derived_from(:type) { |type|
			if INBOUND_TYPES.include?(type)
				"in"
			elsif OUTBOUND_TYPES.include?(type)
				"out"
			else
				raise "Generated bad webhook type #{type}"
			end
		}, transient: true
		description { string }
		to { nanpa_phone }
        message derived_from(:direction, :to), &Message.new.method(:generate)
	}
end
