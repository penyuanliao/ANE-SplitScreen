package com.ios.UIKit
{
	import flash.display.Screen;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.utils.getTimer;

	public class SplitScreen extends EventDispatcher
	{
		private var _ec:ExtensionContext;
		
		private static const extensionID:String = "com.ane.os.device.info";
		
		/**
		 * 初始化ANE物件, 監聽ANE回傳事件, ANE初始化
		 **/
		public function SplitScreen()
		{
			_ec = ExtensionContext.createExtensionContext(extensionID, null);
			//extension ansyc event
			_ec.addEventListener(StatusEvent.STATUS, handleContextStatus2);
			
			trace("[AS3] Initization Split Screen.");
			_ec.call("init");
		}
		
		protected function handleContextStatus2(e:StatusEvent):void
		{
			trace("Event:" + e.code + ",Value:" + e.level);
		}
		/**初始化**/
		/** 開啟影像 **/
		public function connect(url:String):void
		{
			_ec.call("videoConnect",url);
		}
		/** 關閉影像 **/
		public function close():void
		{
			_ec.call("videoClose");
		}
		
	}
}