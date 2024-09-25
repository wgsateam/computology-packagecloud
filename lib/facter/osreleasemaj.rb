# frozen_string_literal: true

Facter.add('osreleasemaj') do
  setcode do
    Facter.value(:operatingsystemrelease)&.split('.')&.first
  end
end
