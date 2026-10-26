#nullable disable
using System;
using System.IO;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;

namespace Cyrus.Content {
    // Closed bounded JSON data. Shared by library workers, never executable content.
    internal static class LibraryJson {
        internal static Dictionary<string,object> Obj(object value) {
            var result=value as Dictionary<string,object>;if(result==null)throw new IOException("Library object required.");return result;
        }
        internal static List<object> Arr(object value) {
            var result=value as List<object>;if(result==null)throw new IOException("Library array required.");return result;
        }
        internal static string Str(object value) {if(!(value is string))throw new IOException("Library text required.");return (string)value;}
        internal static long Int(object value) {if(!(value is long)&&!(value is int))throw new IOException("Library integer required.");return Convert.ToInt64(value,CultureInfo.InvariantCulture);}
        internal static Dictionary<string,object> Map(params object[] values) {
            var d=new Dictionary<string,object>(StringComparer.Ordinal);for(int i=0;i<values.Length;i+=2)d.Add((string)values[i],values[i+1]);return d;
        }
        internal static object Parse(string text,int maxBytes=33554432) {
            if(text==null||Encoding.UTF8.GetByteCount(text)>maxBytes)throw new IOException("Library metadata exceeds its bound.");
            int at=0,nodes=0;
            Action space=()=>{while(at<text.Length&&" \r\n\t".IndexOf(text[at])>=0)at++;};
            Func<IOException> bad=()=>new IOException("Invalid library JSON at character "+at+".");
            Action<char> take=c=>{space();if(at>=text.Length||text[at++]!=c)throw bad();};
            Func<string> readString=()=>{
                take('"');var output=new StringBuilder();
                while(at<text.Length){char c=text[at++];if(c=='"')return output.ToString();if(c<32)throw bad();
                    if(c=='\\'){if(at>=text.Length)throw bad();c=text[at++];switch(c){
                        case '"':case '/':case '\\':break;case 'n':c='\n';break;case 'r':c='\r';break;case 't':c='\t';break;case 'b':c='\b';break;case 'f':c='\f';break;
                        case 'u':ushort n;if(at+4>text.Length||!UInt16.TryParse(text.Substring(at,4),NumberStyles.HexNumber,CultureInfo.InvariantCulture,out n))throw bad();at+=4;c=(char)n;break;default:throw bad();}}
                    output.Append(c);
                }throw bad();
            };
            Func<int,object> read=null;
            read=depth=>{
                if(depth>64||++nodes>1000000)throw bad();space();if(at>=text.Length)throw bad();
                char c=text[at];if(c=='"')return readString();
                if(c=='{'){at++;var d=new Dictionary<string,object>(StringComparer.Ordinal);space();if(at<text.Length&&text[at]=='}'){at++;return d;}
                    while(true){string k=readString();take(':');if(d.ContainsKey(k))throw bad();d.Add(k,read(depth+1));space();if(at>=text.Length)throw bad();c=text[at++];if(c=='}')return d;if(c!=',')throw bad();}}
                if(c=='['){at++;var a=new List<object>();space();if(at<text.Length&&text[at]==']'){at++;return a;}
                    while(true){a.Add(read(depth+1));space();if(at>=text.Length)throw bad();c=text[at++];if(c==']')return a;if(c!=',')throw bad();}}
                foreach(string w in new[]{"true","false","null"})if(at+w.Length<=text.Length&&text.Substring(at,w.Length)==w){at+=w.Length;return w=="null"?null:(object)(w=="true");}
                int start=at;if(c=='-')at++;if(at>=text.Length||text[at]<'0'||text[at]>'9')throw bad();
                bool zero=text[at++]=='0';if(!zero)while(at<text.Length&&Char.IsDigit(text[at]))at++;
                bool real=false;if(at<text.Length&&text[at]=='.'){real=true;at++;int digits=at;while(at<text.Length&&text[at]>='0'&&text[at]<='9')at++;if(at==digits)throw bad();}
                if(at<text.Length&&(text[at]=='e'||text[at]=='E')){real=true;at++;if(at<text.Length&&(text[at]=='+'||text[at]=='-'))at++;int digits=at;while(at<text.Length&&text[at]>='0'&&text[at]<='9')at++;if(at==digits)throw bad();}
                string token=text.Substring(start,at-start);long integer;double number;
                if(!real&&Int64.TryParse(token,NumberStyles.AllowLeadingSign,CultureInfo.InvariantCulture,out integer))return integer;
                if(!Double.TryParse(token,NumberStyles.Float,CultureInfo.InvariantCulture,out number)||Double.IsInfinity(number)||Double.IsNaN(number))throw bad();return number;
            };
            var result=read(0);space();if(at!=text.Length)throw bad();return result;
        }
        internal static string Write(object value) {
            var b=new StringBuilder();Action<string> quote=s=>{b.Append('"');foreach(char c in s){switch(c){case '"':b.Append("\\\"");break;case '\\':b.Append("\\\\");break;case '\n':b.Append("\\n");break;case '\r':b.Append("\\r");break;case '\t':b.Append("\\t");break;default:if(c<32)b.Append("\\u"+((int)c).ToString("x4"));else b.Append(c);break;}}b.Append('"');};
            Action<object,int> write=null;write=(v,depth)=>{
                if(depth>64||b.Length>33554432)throw new IOException("Library metadata exceeds its bound.");
                if(v==null){b.Append("null");return;}if(v is string){quote((string)v);return;}if(v is bool){b.Append((bool)v?"true":"false");return;}
                var d=v as Dictionary<string,object>;if(d!=null){b.Append('{');bool first=true;var keys=new List<string>(d.Keys);keys.Sort(StringComparer.Ordinal);foreach(string k in keys){if(!first)b.Append(',');first=false;quote(k);b.Append(':');write(d[k],depth+1);}b.Append('}');return;}
                var array=v as IEnumerable;if(array!=null){b.Append('[');bool first=true;foreach(var item in array){if(!first)b.Append(',');first=false;write(item,depth+1);}b.Append(']');return;}
                if(v is double||v is float){double n=Convert.ToDouble(v,CultureInfo.InvariantCulture);if(Double.IsNaN(n)||Double.IsInfinity(n))throw new IOException("Nonfinite library value.");b.Append(n.ToString("R",CultureInfo.InvariantCulture));return;}
                if(v is int||v is long){b.Append(Convert.ToString(v,CultureInfo.InvariantCulture));return;}throw new IOException("Unsupported library data type.");
            };write(value,0);return b.ToString();
        }
    }
}
