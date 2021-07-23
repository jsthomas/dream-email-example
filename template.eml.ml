let show_form ?alert request =
  <html>
  <body>
  <div>
    <h3>Send an Email</h3>
    <div>
%   begin match alert with
%   | None -> ()
%   | Some text ->
         <p><%s text %></p>
%   end;
    </div>
    <div>
      <%s! Dream.form_tag ~action:"/" request %>
        <div>Address:</div> <input name="address" autofocus>
        <br>
        <br>
        <div>Subject:</div> <input name="subject">
        <br>
        <br>
        <div>Message:</div>
        <textarea name="message" rows="5" cols="80"> </textarea>
        <br>
        <br>
        <button type=submit>Send!</button>
      </form>
    </div>
  </div>
  </body>
  </html>
