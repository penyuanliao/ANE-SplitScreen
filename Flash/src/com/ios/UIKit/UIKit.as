package com.ios.UIKit
{

	import com.ios.UIKit.event.AlertEvent;
	import com.ios.UIKit.event.ImagePickerEvent;
	import com.ios.UIKit.event.LocationEvent;
	import com.ios.UIKit.event.ScannerEvent;
	
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.display.Screen;

	public class UIKit extends EventDispatcher
	{
		private var _ec:ExtensionContext;
		
		private static const extensionID:String = "com.ane.os.device.info";
		
		/**
		 * 初始化ANE物件, 監聽ANE回傳事件, ANE初始化
		 **/
		public function UIKit()
		{
			_ec = ExtensionContext.createExtensionContext("com.ane.os.device.info",null);
			//extension ansyc event
			_ec.addEventListener(StatusEvent.STATUS,handleContextStatus2);
			
			trace("init");
		}
		
		protected function handleContextStatus2(e:StatusEvent):void
		{
			// TODO Auto-generated method stub
			trace("Event:" + e.code + "Value:" + e.level);
			trace("::: FLASH Screens: "+ Screen.screens.length +":::");
		}
		
//		public function init():void
//		{
//			_ec.call("init");	
//			_ec.call("showAlert","START","Extension","ENTER","CANCEL");
			//this.handleContextStatus(new StatusEvent(StatusEvent.STATUS));
//		}
		
		public function showAlert(title:String, content:String, cancel:String, orders:Array):void
		{
			_ec.call("init");
//			_ec.call("showAlert", title, content, cancel, orders);
		}
		public function showInputAlert(title:String, content:String, cancel:String, order:String):void
		{
//			_ec.call("showInputAlert", title, content, cancel, order);
		}
//		public function showActionSheet(title:String, content:String, orders:Array):void
//		{
//			_ec.call("showActionSheet", title, content, orders);
//		}
		
//		public function startLocation():void
//		{
//			_ec.call("startLocation");
//		}
//		/* 掃描QRCode */
//		public function qrcodeScanner():void
//		{
//			_ec.call("qrcodeScanner");
//		}
//		/* Show iOS Photos Albums.*/
//		public function showImagePicker():void
//		{
//
//			_ec.call("showImagePicker");
//
//		}
//		/* return byteArray data */
//		public function pickedImageJPEGData():ByteArray
//		{
//			var bytes:ByteArray = new ByteArray();
//			
//			_ec.call("getPickedImageJPEGData", bytes);
//			
//			return bytes;
//		}
//		/* 處理圖片回傳 */
//		public function pickedImageWithBitmapData():BitmapData
//		{
//			var w:int = _ec.call("getImageSizeWidth") as int;
//			var h:int = _ec.call("getImageSizeHeight") as int;
//			
//			var _bitmap:BitmapData = new BitmapData(w, h);
//			_ec.call("getPickedimageWithBitmData", _bitmap);
//			
//			return _bitmap;
//		}
//		public function crashlyticsStart():void
//		{
//			
//			_ec.call("crashlyticsStart");
//			
//		}
//		public function crashlyticsCrash():void
//		{
//			
//			_ec.call("crashlyticsCrash");
//			
//		}
//		public function showHUD(endTime:Number):void
//		{
//			_ec.call("showHUD",endTime);
//		}
//		//test 
//		public function testString(txt:String):String
//		{
//			return _ec.call("testString",txt) as String;
//		}
//		public function testArray(array:Array):Array
//		{
//			return _ec.call("testArray",array) as Array;
//		}
//		public function getDeviceInfo():Object
//		{
//			var obj:Object = new Object();
//			_ec.call("getDeviceInfo", obj);
//			return obj;
//		}
		/*private function handleContextStatus(e:StatusEvent):void
		{
			trace("Event:" + e.code);
			trace("Value:" + e.level);
			//_ec.call("showAlert","as::status"+e.code,"index:"+e.level,"ENTER", "");
			if(e.code == AlertEvent.ONCLICK)
			{
				trace("ONCLICK");
				dispatchEvent(new AlertEvent(AlertEvent.ONCLICK,Number(e.level)));
			}
			else if(e.code == AlertEvent.ONINPUTCLICK)
			{
				trace("ONINPUTCLICK");
				var mydata:Object = JSON.parse(e.level);
				
				dispatchEvent(new AlertEvent(AlertEvent.ONINPUTCLICK, Number(mydata.buttonIndex), mydata.textInput));	
			}
			else if(e.code == LocationEvent.UPDATE)
			{
				trace("LocationEvent:UPDATE");
				dispatchEvent(new LocationEvent(LocationEvent.UPDATE, e.level));
			}
			else if(e.code == ScannerEvent.UPDATE)
			{
				trace("ScannerEvent:UPDATE");
				dispatchEvent(new ScannerEvent(ScannerEvent.UPDATE, e.level));
			}
			else if (e.code == ImagePickerEvent.ON_FINISH_EVENT)
			{
				var startTimer:Number = getTimer();
				
				
				var w:int = _ec.call("getImageSizeWidth") as int;
				var h:int = _ec.call("getImageSizeHeight") as int;
				
				var _bitmap:BitmapData = new BitmapData(w, h);
				_ec.call("getPickedimageWithBitmData", _bitmap);
				
				var bytes:ByteArray = new ByteArray();
				
				_ec.call("getPickedImageJPEGData", bytes);
				
				trace(e.code, "second:", startTimer - getTimer());
				
				dispatchEvent(new ImagePickerEvent(ImagePickerEvent.ON_COMPLETE_EVENT, w, h, bytes, _bitmap));
				
			}
			else
			{
				dispatchEvent(new StatusEvent(StatusEvent.STATUS,false,false,e.code,e.level));
			}
			
		}*/
		
	}
}