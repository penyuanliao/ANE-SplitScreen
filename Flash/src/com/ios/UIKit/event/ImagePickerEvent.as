package com.ios.UIKit.event
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class ImagePickerEvent extends Event
	{
		public static const ON_FINISH_EVENT:String = "onFinishPickedMedia";
		
		public static const ON_COMPLETE_EVENT:String = "onCompletePickedMedia";
		
		private var imageWidth:int;
		
		private var imageHeight:int;
		
		private var imageByteArray:ByteArray;
		
		private var imageBitmapData:BitmapData;
		
		public function ImagePickerEvent(type:String,_imgW:int,_imgH:int, _imgByteArray:ByteArray, _imgBitmapData:BitmapData, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			imageWidth = _imgW;
			
			imageHeight = _imgH;
			
			imageByteArray = _imgByteArray;
			
			imageBitmapData = _imgBitmapData;
			
			super(type, bubbles, cancelable);
		}
		/* Width */
		public function get getImageWidth():int
		{
			return imageWidth;
		}
		/* Height */
		public function get getImageHeight():int
		{
			return imageHeight;
		}
		/* ByteArray */
		public function get getImageByteArray():ByteArray
		{
			return imageByteArray;
		}
		/* BitmapData */
		public function get getImageBitmapData():BitmapData
		{
			return imageBitmapData;
		}
	}
}