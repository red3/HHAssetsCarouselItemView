Pod::Spec.new do |spec|
  spec.name         = "HHAssetsCarouselItemView"
  spec.version      = "0.0.1"
  spec.authors      = { "Herui" => "heruicross@gmail.com" }
  spec.homepage     = "https://github.com/red3/HHAssetsCarouselItemView"
	spec.summary      = "HHAssetsCarouselItemView enables you to pick a assets in your Photo Library like Messages app."
	spec.source       = { :git => "https://github.com/red3/HHAssetsCarouselItemView.git", :tag => spec.version.to_s }
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.platform = :ios, '7.0'
  spec.source_files = "HHAssetsCarouselItemView/*"

  spec.requires_arc = true

	spec.dependency "TGMediaAssets" 
	spec.dependency "HHCheckboxButton" 
	spec.dependency "HHAttachmentSheetView" 

  spec.ios.deployment_target = '7.0'
  spec.ios.frameworks = ['UIKit', 'Foundation'] 
end
