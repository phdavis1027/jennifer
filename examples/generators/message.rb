# frozen_string_literal: true

require "jennifer"

class Message
	module SegmentLimit
		GSM_7 = 160
		UCS_2 = 70
	end
	CHANNELS = ["sms", "mms", "rbm"]

	include Jennifer.rant(self) { |dir, to|
		to { array { nanpa_phone } }
		from { nanpa_phone }
		owner derived_from(:to, :from) { |to, from|
			case dir
			when "in"
				choose(*to)
			when "out"
				from
			end
		}
		direction { dir }
		text { string }
		stanza_id(transient: true) { string }
		resourcepart(transient: true) { string }
		tag derived_from(:stanza_id, :resourcepart) { |stanza_id, resourcepart|
			[stanza_id, resourcepart].join(" ")
		}
		application_id { string }
		channel { choose(*CHANNELS) }
		segment_count derived_from(:channel, :text) { |channel, text|
			case channel
			when "mms"
				1
			when "sms", "rbm"
				text.size % choose(SegmentLimit::GSM_7, SegmentLimit::UCS_2) + 1
			end
		}
	}
end
