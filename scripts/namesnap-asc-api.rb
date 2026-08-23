#!/usr/local/opt/ruby/bin/ruby

require "json"
require "net/http"
require "spaceship"
require "uri"

APP_ID = "6759588637"
KEY_ID = "4HA95XB6S5"
ISSUER_ID = "67c52852-b22f-4e49-ad81-df53bf4476fb"
KEY_PATH = "/Users/marcuskim/.AuthKey_4HA95XB6S5.p8"

token = Spaceship::ConnectAPI::Token.create(
  key_id: KEY_ID,
  issuer_id: ISSUER_ID,
  filepath: KEY_PATH
)

def request(token, method, path, body: nil, allow_not_found: false)
  uri = URI("https://api.appstoreconnect.apple.com#{path}")
  request_class = {
    get: Net::HTTP::Get,
    post: Net::HTTP::Post,
    patch: Net::HTTP::Patch,
    delete: Net::HTTP::Delete
  }.fetch(method)
  req = request_class.new(uri)
  req["Authorization"] = "Bearer #{token.text}"
  req["Content-Type"] = "application/json" if body
  req.body = JSON.generate(body) if body
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  parsed = response.body.to_s.empty? ? {} : JSON.parse(response.body)
  return {} if allow_not_found && response.code.to_i == 404
  unless response.code.to_i.between?(200, 299)
    details = Array(parsed["errors"]).map do |error|
      [error["status"], error["code"], error["title"], error["detail"]].compact.join(" · ")
    end
    abort("App Store Connect API #{response.code}: #{details.join(" | ")}")
  end
  parsed
end

def beta_groups(token)
  request(token, :get, "/v1/betaGroups?filter%5Bapp%5D=#{APP_ID}&limit=200").fetch("data", [])
end

def beta_group_builds(token, group_id)
  request(token, :get, "/v1/betaGroups/#{group_id}/builds?limit=200").fetch("data", [])
end

def build_for(token, build_number)
  request(
    token,
    :get,
    "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=#{URI.encode_www_form_component(build_number)}&sort=-uploadedDate&limit=1"
  ).fetch("data", []).first
end

def add_build_to_group(token, group_id, build_id)
  request(
    token,
    :post,
    "/v1/betaGroups/#{group_id}/relationships/builds",
    body: { data: [{ type: "builds", id: build_id }] }
  )
end

def app_store_versions(token)
  request(
    token,
    :get,
    "/v1/apps/#{APP_ID}/appStoreVersions?filter%5Bplatform%5D=IOS&limit=20"
  ).fetch("data", [])
end

def version_submission(token, version_id)
  request(
    token,
    :get,
    "/v1/appStoreVersions/#{version_id}/relationships/appStoreVersionSubmission",
    allow_not_found: true
  )["data"]
end

def review_submissions(token)
  request(token, :get, "/v1/apps/#{APP_ID}/reviewSubmissions?limit=200").fetch("data", [])
end

case ARGV.fetch(0, "build-status")
when "build-status"
  build_number = ARGV.fetch(1, "13")
  build = build_for(token, build_number)
  puts JSON.pretty_generate(
    build: build && {
      id: build["id"],
      build_number: build.dig("attributes", "version"),
      processing_state: build.dig("attributes", "processingState"),
      uploaded_date: build.dig("attributes", "uploadedDate"),
      expired: build.dig("attributes", "expired")
    }
  )
when "distribute-build"
  build_number = ARGV.fetch(1)
  build = build_for(token, build_number)
  abort("Build #{build_number} is not available in App Store Connect") unless build
  abort("Build #{build_number} is not valid") unless build.dig("attributes", "processingState") == "VALID"

  groups = beta_groups(token).select { |group| group.dig("attributes", "isInternalGroup") }
  abort("NameSnap has no internal TestFlight group") if groups.empty?
  groups.each do |group|
    next if beta_group_builds(token, group.fetch("id")).any? { |candidate| candidate["id"] == build["id"] }

    add_build_to_group(token, group.fetch("id"), build.fetch("id"))
  end
  puts JSON.pretty_generate(
    build_number: build_number,
    build_id: build["id"],
    groups: groups.map { |group| { id: group["id"], name: group.dig("attributes", "name") } }
  )
when "testflight-status"
  build_number = ARGV.fetch(1, "13")
  puts JSON.pretty_generate(
    groups: beta_groups(token).map do |group|
      {
        id: group["id"],
        name: group.dig("attributes", "name"),
        internal: group.dig("attributes", "isInternalGroup"),
        builds: beta_group_builds(token, group.fetch("id")).filter_map do |build|
          next unless build.dig("attributes", "version") == build_number

          {
            id: build["id"],
            build_number: build_number,
            processing_state: build.dig("attributes", "processingState"),
            expired: build.dig("attributes", "expired")
          }
        end
      }
    end
  )
when "submission-status"
  puts JSON.pretty_generate(
    review_submissions: review_submissions(token).map do |submission|
      {
        id: submission["id"],
        state: submission.dig("attributes", "state"),
        submitted_date: submission.dig("attributes", "submittedDate"),
        platform: submission.dig("attributes", "platform")
      }
    end,
    versions: app_store_versions(token).map do |version|
      {
        id: version["id"],
        version: version.dig("attributes", "versionString"),
        state: version.dig("attributes", "appStoreState"),
        submission: version_submission(token, version.fetch("id"))
      }
    end
  )
when "cancel-submission"
  submission = review_submissions(token).find do |candidate|
    %w[WAITING_FOR_REVIEW IN_REVIEW].include?(candidate.dig("attributes", "state"))
  end
  abort("NameSnap has no review submission that can be canceled") unless submission

  updated = request(
    token,
    :patch,
    "/v1/reviewSubmissions/#{submission.fetch("id")}",
    body: {
      data: {
        type: "reviewSubmissions",
        id: submission.fetch("id"),
        attributes: { canceled: true }
      }
    }
  ).fetch("data")
  puts JSON.pretty_generate(
    submission_id: submission["id"],
    previous_state: submission.dig("attributes", "state"),
    current_state: updated.dig("attributes", "state"),
    canceled: true
  )
else
  abort("Unknown command: #{ARGV[0]}")
end
