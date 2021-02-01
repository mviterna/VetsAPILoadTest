#!/usr/bin/env ruby
require 'rest-client'
require 'json'
require 'progress'

apikey = ''

files = Dir.glob('pdf/*')

attempts = 10

pendings = 0

threads = []

(0...attempts).each do |num|

  threads << Thread.new {

  post_response = RestClient.post("https://sandbox-api.va.gov/services/vba_documents/v1/uploads", nil,  apikey: apikey)

  parsed = JSON.parse(post_response.body)['data']

  boundary = parsed['id'].split('-').first

  content = files.sample

  attachment = files.sample

  payload = "--#{boundary}
  Content-Disposition: form-data; name='metadata'
  Content-Type: application/json

  {'veteranFirstName': 'Jane', 'veteranLastName': 'Doe', 'fileNumber': '012345678', 'zipCode': '97202', 'source': 'MyVSO', 'docType': '21-22'}
  --#{boundary}
  Content-Disposition: form-data; name='content'
  Content-Type: application/pdf

  #{IO.read("#{content}")}
  --#{boundary}
  Content-Disposition: form-data; name='attachment1'
  Content-Type: application/pdf

  #{IO.read("#{attachment}")}
  --#{boundary}--"

  begin
    put_response = RestClient.put(parsed['attributes']['location'],
                            payload,
                            { 'Content-Encoding': 'application/pdf',
                              "Content-Type": "multipart/form-data; boundary=#{boundary}",
                              accept: :json})
    unless put_response.body.empty?
      pendings = pendings + 1
      puts Time.now
      puts parsed['attributes']['location']
      puts "status: #{put_response.code}"
      puts "cookies: #{put_response.cookies}"
      puts "headers: #{put_response.headers}"
      puts put_response.body.inspect
      puts "content: #{content}"
      puts "attachement: #{attachment}"
    end
  rescue => e
    pendings = pendings + 1
    puts parsed['attributes']['location']
    puts e.inspect
  end

  }

end

threads.with_progress.each { |thr| thr.join }

puts "Total Attempts: #{attempts}"
puts "Total Failures: #{pendings}"
puts "Error rate: #{(100.0/attempts)*pendings}"
