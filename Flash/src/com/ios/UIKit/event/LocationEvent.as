package com.ios.UIKit.event
{
	import flash.events.Event;
	import flash.geom.Point;
	
	public class LocationEvent extends Event
	{
		public static const UPDATE:String = "onUpdate";
		public static const Disabled:String = "onDisabled";
		
		private var pos:String = "";
		public function LocationEvent(type:String, _pos:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			pos = _pos;
			super(type, bubbles, cancelable);
		}
		public function get position():Point
		{
			var array:Array = pos.split(",");
			return new Point(array[0],array[1]);
		}
	}
}