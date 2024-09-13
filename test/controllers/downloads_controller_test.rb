require 'test_helper'

class DownloadsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @rich_text = action_text_rich_texts(:rich_text_four)
    @dummy_file_path = Rails.root.join('tmp', 'dummy.epub')
    FileUtils.touch(@dummy_file_path)
  end

  test "should generate and send epub file" do
    mock_epub_generator = Minitest::Mock.new
    mock_epub_generator.expect :generate, nil
    mock_epub_generator.expect :file_path, @dummy_file_path.to_s
    mock_epub_generator.expect :filename, 'generated_book.epub'

    EpubGenerator.stub :new, mock_epub_generator do
      get epub_download_path(id: @rich_text)
    end

    assert_response :success
    assert_equal 'application/epub+zip', response.content_type
    assert_equal "attachment; filename=\"generated_book.epub\"; filename*=UTF-8''generated_book.epub", response.headers['Content-Disposition']

    mock_epub_generator.verify
  end

  test "should handle error and redirect" do
    EpubGenerator.stub :new, ->(_) { raise StandardError } do
      get epub_download_path(id: @rich_text)
    end

    assert_redirected_to 'http://www.example.com/'
    assert_equal 'Ох, тр*сця! Під час генерування EPUB сталася помилка!', flash[:alert]
  end
end
