package com.ios.UIKit.event
{
	import flash.events.Event;
	
	public class ScannerEvent extends Event
	{
		public static const UPDATE:String = "onUpdateScanner";
		
		private var symbolStr:String = "";
		
		public function ScannerEvent(type:String, _symbol:String = "", bubbles:Boolean=false, cancelable:Boolean=false)
		{
			symbolStr = _symbol;
			super(type, bubbles, cancelable);
		}
		
		public function get symbol():String
		{
			return symbolStr;
		}
	}
}