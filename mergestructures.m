function mergedstructure = mergestructures(struct1,struct2)
mergedstructure=struct1;
f = fieldnames(struct2);
for i = 1:length(f)
  mergedstructure.(f{i}) = struct2.(f{i});
end
