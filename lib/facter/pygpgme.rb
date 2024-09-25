# frozen_string_literal: true

Facter.add('pygpgme_installed') do
  setcode do
    os = Facter.value(:operatingsystem).downcase

    case os
    when /debian|ubuntu|windows/
      'true'
    else
      output = Facter::Core::Execution.exec('rpm -q pygpgme')
      if output.start_with?('pygpgme')
        'true'
      else
        'false'
      end
    end
  end
end
