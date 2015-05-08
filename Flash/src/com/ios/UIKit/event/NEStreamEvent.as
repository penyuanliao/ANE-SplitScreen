package com.ios.UIKit.event
{
	import flash.events.Event;
	import flash.geom.Point;
	
	public class NEStreamEvent extends Event
	{
		public static const STREAM_FPS:String = "streamFPSInfo";
		public static const METADATA_INFO:String = "onMetaDataInfo";
		private var val:String = "";
		public function NEStreamEvent(type:String, _val:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			val = _val;
			super(type, bubbles, cancelable);
		}
		public function get position():Point
		{
			var array:Array = val.split(",");
			return new Point(array[0],array[1]);
		}
	}
}

