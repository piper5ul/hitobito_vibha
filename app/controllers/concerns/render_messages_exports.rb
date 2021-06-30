# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RenderMessagesExports
  extend ActiveSupport::Concern

  def render_pdf_preview(message)
    assert_type(message)
    assert_recipients(message)

    options = { background: Settings.messages.pdf.preview }
    pdf = message.exporter_class.new(message, limited_recipients(message), options)
    send_data pdf.render, type: :pdf, disposition: :inline, filename: pdf.filename(:preview)
  end

  def render_pdf_in_background(message)
    assert_type(message)
    assert_recipients(message)

    base_name = message.exporter_class.new(message, Person.none, preview: false).filename
    with_async_download_cookie(:pdf, base_name) do |filename|
      Export::MessageJob.new(current_person.id, message.id, filename).enqueue!
    end
  end

  private

  def assert_type(message)
    raise "cannot create pdf for #{message.type}" unless message.is_a?(Message::Letter)
  end

  def assert_recipients(message)
    if limited_recipients(message).count == 0
      raise Messages::NoRecipientsError
    end
  end

  def limited_recipients(message)
    message.recipients.limit(5) # no need to query all recipients
  end

end
