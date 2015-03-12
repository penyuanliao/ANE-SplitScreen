package com.ios.UIKit.event
{
	import flash.events.Event;
	
	public class AlertEvent extends Event
	{
		//點擊物件事件
		public static const ONCLICK:String = "onClick";
		//有輸入框事件
		public static const ONINPUTCLICK:String = "onSendInput";
		
		private var buttonAtIndex:Number = -1;
		
		private var input:String = "";
		/**
		 * Send events from Objective-C to ActionScript 
		 **/
		public function AlertEvent(type:String, idx:Number, _input:String = "", bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.buttonAtIndex = idx;
			this.input = _input;
			super(type, bubbles, cancelable);
		}
		/** 
		 * return Event onClick Button index identity
		 **/
		public function get selectedIndex():Number
		{
			return this.buttonAtIndex;
		}
		/**
		 * return Event onSendInput input text 
		 **/
		public function get textInput():String
		{
			return this.input;
		}
	}
}