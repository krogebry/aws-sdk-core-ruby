def upload_glacier_archive(contents)
  @response = @glacier.upload_archive(
    vault_name: @vault_name,
    account_id: '-',
    body: contents)
  @archive_id = @response.archive_id
end

When(/^I upload an archive with the contents "(.*?)"$/) do |contents|
  upload_glacier_archive(contents)
end

When(/^I upload an archive from a (\d+\.\d+)MB large file$/) do |size|
  file = Tempfile.new('aws-sdk-core-glacier-sample')
  file.write('.' * (1024 * 1024 * size.to_f).to_i)
  file.rewind
  upload_glacier_archive(file)
end

Then(/^I should be able to delete the archive$/) do
  @glacier.delete_archive(
    vault_name: @vault_name,
    account_id: '-',
    archive_id: @archive_id)
end
