# frozen_string_literal: true

Facter.add('pygpgme_installed') do
  setcode do
    osfamily = Facter.value(:osfamily)

    if osfamily == 'RedHat'
      output = Facter::Core::Execution.exec('rpm -q pygpgme')
      output && output.start_with?('pygpgme') ? 'true' : 'false'
    else
      'false' # Default to false for non-RedHat systems
    end
  end
end
