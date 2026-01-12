function main() {
  let Person = function(val) {
    this.val = val;
  };
  Person.prototype.getVal = function() {
    return this.val;
  };
  
  let p = new Person(100);
  console.log(p.getVal());
}
