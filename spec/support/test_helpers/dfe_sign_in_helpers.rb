module DfESignInHelpers
  def provider_exists_in_dfe_sign_in(email_address: 'email@provider.ac.uk', dfe_sign_in_uid: 'DFE_SIGN_IN_UID')
    OmniAuth.config.mock_auth[:dfe] = OmniAuth::AuthHash.new(
      fake_dfe_sign_in_auth_hash(email_address: email_address, dfe_sign_in_uid: dfe_sign_in_uid),
    )
  end

  def provider_signs_in_using_dfe_sign_in
    visit provider_interface_path
    click_link 'Sign in using DfE Sign-in'
  end

  def fake_dfe_sign_in_auth_hash(email_address:, dfe_sign_in_uid:)
    {
      'provider' => 'dfe',
      'uid' => dfe_sign_in_uid,
      'info' => {
        'name' => 'Firstname Lastname',
        'email' => email_address,
        'nickname' => nil,
        'first_name' => 'Firstname',
        'last_name' => 'Lastname',
        'gender' => nil,
        'image' => nil,
        'phone' => nil,
        'urls' => { 'website' => nil },
      },
      'credentials' => {
        'id_token' => '',
        'token' => 'DFE_SIGN_IN_TOKEN',
        'refresh_token' => nil,
        'expires_in' => 3600,
        'scope' => 'email openid',
      },
      'extra' => {
        'raw_info' => {
          'email' => email_address,
          'sub' => dfe_sign_in_uid,
        },
      },
    }
  end
end
