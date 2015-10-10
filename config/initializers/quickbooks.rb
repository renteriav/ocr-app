QB_KEY = "qyprd9VMXsHO7t6RJazhO3beTh6ihC"
QB_SECRET = "EbpTRkdRR63e8bZtB7LseqivC9yzDDgX2eYLdLjm"

$qb_oauth_consumer = OAuth::Consumer.new(QB_KEY, QB_SECRET, {
    :site                 => "https://oauth.intuit.com",
    :request_token_path   => "/oauth/v1/get_request_token",
    :authorize_url        => "https://appcenter.intuit.com/Connect/Begin",
    :access_token_path    => "/oauth/v1/get_access_token"
})

Quickbooks.sandbox_mode = true