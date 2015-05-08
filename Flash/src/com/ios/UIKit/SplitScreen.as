package com.ios.UIKit
{
	import com.ios.UIKit.event.NEStreamEvent;
	
	import flash.display.Screen;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.utils.getTimer;

	public class SplitScreen extends EventDispatcher
	{
		private var _ec:ExtensionContext;
		
		private var _fpsEnabled:Boolean = false;
		
		private var _metaDataEnabled:Boolean = false;
		
		private static const extensionID:String = "com.ane.os.device.info";
		
		/**
		 * 初始化ANE物件, 監聽ANE回傳事件, ANE初始化
		 **/
		public function SplitScreen()
		{
			//create Extension bridge objC
			_ec = ExtensionContext.createExtensionContext(extensionID, null);
			//extension ansyc event
			_ec.addEventListener(StatusEvent.STATUS, handleContextStatus);
			
			trace("[AS3] Initization Split Screen.");
			_ec.call("init");
			
		}
		
		protected function handleContextStatus(e:StatusEvent):void
		{
			trace("Event:" + e.code + ",Value:" + e.level);
			var evt:NEStreamEvent = null;
			if (e.code == "NEStreamFrameOnFPS" && _fpsEnabled)
			{
				evt = new NEStreamEvent(NEStreamEvent.STREAM_FPS, e.level);
				dispatchEvent(evt);
			}
			else if (e.code == "NEStreamOnMetaData" && _metaDataEnabled)
			{
				evt = new NEStreamEvent(NEStreamEvent.METADATA_INFO, e.level);
				dispatchEvent(evt);
			}
			
		}
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
		/** fps dispatch event **/
		public function set fpsEnabled(bool:Boolean):void
		{
			_fpsEnabled = bool;
			_ec.call("dispatchStreamFPSInfo", _fpsEnabled);
		}
		public function get fpsEnabled():Boolean
		{
			return fpsEnabled;
		}
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			if (type == NEStreamEvent.STREAM_FPS)
			{
				trace("add STREAM_FPS event.");
			}
			if (type == NEStreamEvent.METADATA_INFO)
			{
				trace("add METADATA_INFO event.");
				
				_metaDataEnabled = true;
				_ec.call("dispatchStreamMetaDataInfo", _metaDataEnabled);
			}
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			if (type == NEStreamEvent.STREAM_FPS)
			{
				trace("remove STREAM_FPS event.");
			}
			if (type == NEStreamEvent.METADATA_INFO)
			{
				trace("remove METADATA_INFO event.");
				
				_metaDataEnabled = false;
			}
			super.addEventListener(type, listener, useCapture);
		}
	}
}