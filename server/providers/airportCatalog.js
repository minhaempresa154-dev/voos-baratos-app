const AIRPORTS = [
  { iataCode: "GRU", name: "Aeroporto Internacional de Sao Paulo-Guarulhos", city: "Sao Paulo", country: "BR" },
  { iataCode: "CGH", name: "Aeroporto de Congonhas", city: "Sao Paulo", country: "BR" },
  { iataCode: "VCP", name: "Aeroporto Internacional de Viracopos", city: "Campinas", country: "BR" },
  { iataCode: "GIG", name: "Aeroporto Internacional Tom Jobim", city: "Rio de Janeiro", country: "BR" },
  { iataCode: "SDU", name: "Aeroporto Santos Dumont", city: "Rio de Janeiro", country: "BR" },
  { iataCode: "BSB", name: "Aeroporto Internacional de Brasilia", city: "Brasilia", country: "BR" },
  { iataCode: "CNF", name: "Aeroporto Internacional de Belo Horizonte", city: "Belo Horizonte", country: "BR" },
  { iataCode: "PLU", name: "Aeroporto da Pampulha", city: "Belo Horizonte", country: "BR" },
  { iataCode: "SSA", name: "Aeroporto Internacional de Salvador", city: "Salvador", country: "BR" },
  { iataCode: "REC", name: "Aeroporto Internacional do Recife", city: "Recife", country: "BR" },
  { iataCode: "FOR", name: "Aeroporto Internacional de Fortaleza", city: "Fortaleza", country: "BR" },
  { iataCode: "POA", name: "Aeroporto Internacional Salgado Filho", city: "Porto Alegre", country: "BR" },
  { iataCode: "CWB", name: "Aeroporto Internacional Afonso Pena", city: "Curitiba", country: "BR" },
  { iataCode: "FLN", name: "Aeroporto Internacional de Florianopolis", city: "Florianopolis", country: "BR" },
  { iataCode: "NVT", name: "Aeroporto Internacional de Navegantes", city: "Navegantes", country: "BR" },
  { iataCode: "JOI", name: "Aeroporto Lauro Carneiro de Loyola", city: "Joinville", country: "BR" },
  { iataCode: "IGU", name: "Aeroporto Internacional de Foz do Iguacu", city: "Foz do Iguacu", country: "BR" },
  { iataCode: "BEL", name: "Aeroporto Internacional de Belem", city: "Belem", country: "BR" },
  { iataCode: "MAO", name: "Aeroporto Internacional Eduardo Gomes", city: "Manaus", country: "BR" },
  { iataCode: "MCZ", name: "Aeroporto Internacional de Maceio", city: "Maceio", country: "BR" },
  { iataCode: "NAT", name: "Aeroporto Internacional de Natal", city: "Natal", country: "BR" },
  { iataCode: "VIX", name: "Aeroporto de Vitoria", city: "Vitoria", country: "BR" },
  { iataCode: "AJU", name: "Aeroporto de Aracaju", city: "Aracaju", country: "BR" },
  { iataCode: "SLZ", name: "Aeroporto Internacional de Sao Luis", city: "Sao Luis", country: "BR" },
  { iataCode: "THE", name: "Aeroporto de Teresina", city: "Teresina", country: "BR" },
  { iataCode: "JPA", name: "Aeroporto Internacional de Joao Pessoa", city: "Joao Pessoa", country: "BR" },
  { iataCode: "CGB", name: "Aeroporto Internacional Marechal Rondon", city: "Cuiaba", country: "BR" },
  { iataCode: "GYN", name: "Aeroporto Santa Genoveva", city: "Goiania", country: "BR" },
  { iataCode: "PMW", name: "Aeroporto de Palmas", city: "Palmas", country: "BR" },
  { iataCode: "BPS", name: "Aeroporto de Porto Seguro", city: "Porto Seguro", country: "BR" },
  { iataCode: "IOS", name: "Aeroporto Jorge Amado", city: "Ilheus", country: "BR" },
  { iataCode: "LDB", name: "Aeroporto de Londrina", city: "Londrina", country: "BR" },
  { iataCode: "MAB", name: "Aeroporto de Maraba", city: "Maraba", country: "BR" },
  { iataCode: "RBR", name: "Aeroporto Internacional de Rio Branco", city: "Rio Branco", country: "BR" },
  { iataCode: "BVB", name: "Aeroporto Internacional de Boa Vista", city: "Boa Vista", country: "BR" },
  { iataCode: "PVH", name: "Aeroporto Internacional de Porto Velho", city: "Porto Velho", country: "BR" },
  { iataCode: "MCP", name: "Aeroporto Internacional de Macapa", city: "Macapa", country: "BR" },
  { iataCode: "JFK", name: "John F. Kennedy International Airport", city: "New York", country: "US" },
  { iataCode: "EWR", name: "Newark Liberty International Airport", city: "Newark", country: "US" },
  { iataCode: "LGA", name: "LaGuardia Airport", city: "New York", country: "US" },
  { iataCode: "MIA", name: "Miami International Airport", city: "Miami", country: "US" },
  { iataCode: "FLL", name: "Fort Lauderdale-Hollywood International Airport", city: "Fort Lauderdale", country: "US" },
  { iataCode: "MCO", name: "Orlando International Airport", city: "Orlando", country: "US" },
  { iataCode: "LAX", name: "Los Angeles International Airport", city: "Los Angeles", country: "US" },
  { iataCode: "SFO", name: "San Francisco International Airport", city: "San Francisco", country: "US" },
  { iataCode: "ORD", name: "Chicago O'Hare International Airport", city: "Chicago", country: "US" },
  { iataCode: "ATL", name: "Hartsfield-Jackson Atlanta International Airport", city: "Atlanta", country: "US" },
  { iataCode: "DFW", name: "Dallas Fort Worth International Airport", city: "Dallas", country: "US" },
  { iataCode: "IAD", name: "Washington Dulles International Airport", city: "Washington", country: "US" },
  { iataCode: "BOS", name: "Logan International Airport", city: "Boston", country: "US" },
  { iataCode: "LAS", name: "Harry Reid International Airport", city: "Las Vegas", country: "US" },
  { iataCode: "YYZ", name: "Toronto Pearson International Airport", city: "Toronto", country: "CA" },
  { iataCode: "YUL", name: "Montreal-Trudeau International Airport", city: "Montreal", country: "CA" },
  { iataCode: "YVR", name: "Vancouver International Airport", city: "Vancouver", country: "CA" },
  { iataCode: "MEX", name: "Aeropuerto Internacional Benito Juarez", city: "Mexico City", country: "MX" },
  { iataCode: "SCL", name: "Aeropuerto Internacional Arturo Merino Benitez", city: "Santiago", country: "CL" },
  { iataCode: "EZE", name: "Aeropuerto Internacional Ministro Pistarini", city: "Buenos Aires", country: "AR" },
  { iataCode: "AEP", name: "Aeroparque Jorge Newbery", city: "Buenos Aires", country: "AR" },
  { iataCode: "MVD", name: "Aeropuerto Internacional de Carrasco", city: "Montevideo", country: "UY" },
  { iataCode: "ASU", name: "Aeropuerto Internacional Silvio Pettirossi", city: "Asuncion", country: "PY" },
  { iataCode: "BOG", name: "Aeropuerto Internacional El Dorado", city: "Bogota", country: "CO" },
  { iataCode: "LIM", name: "Aeropuerto Internacional Jorge Chavez", city: "Lima", country: "PE" },
  { iataCode: "MAD", name: "Adolfo Suarez Madrid-Barajas Airport", city: "Madrid", country: "ES" },
  { iataCode: "BCN", name: "Barcelona-El Prat Airport", city: "Barcelona", country: "ES" },
  { iataCode: "LIS", name: "Aeroporto Humberto Delgado", city: "Lisbon", country: "PT" },
  { iataCode: "OPO", name: "Aeroporto Francisco Sa Carneiro", city: "Porto", country: "PT" },
  { iataCode: "CDG", name: "Paris Charles de Gaulle Airport", city: "Paris", country: "FR" },
  { iataCode: "ORY", name: "Paris Orly Airport", city: "Paris", country: "FR" },
  { iataCode: "LHR", name: "Heathrow Airport", city: "London", country: "GB" },
  { iataCode: "LGW", name: "Gatwick Airport", city: "London", country: "GB" },
  { iataCode: "AMS", name: "Amsterdam Airport Schiphol", city: "Amsterdam", country: "NL" },
  { iataCode: "FCO", name: "Leonardo da Vinci International Airport", city: "Rome", country: "IT" },
  { iataCode: "MXP", name: "Milan Malpensa Airport", city: "Milan", country: "IT" },
  { iataCode: "FRA", name: "Frankfurt Airport", city: "Frankfurt", country: "DE" },
  { iataCode: "MUC", name: "Munich Airport", city: "Munich", country: "DE" },
  { iataCode: "ZRH", name: "Zurich Airport", city: "Zurich", country: "CH" },
  { iataCode: "IST", name: "Istanbul Airport", city: "Istanbul", country: "TR" },
  { iataCode: "DXB", name: "Dubai International Airport", city: "Dubai", country: "AE" },
  { iataCode: "DOH", name: "Hamad International Airport", city: "Doha", country: "QA" },
  { iataCode: "JNB", name: "O. R. Tambo International Airport", city: "Johannesburg", country: "ZA" },
  { iataCode: "NRT", name: "Narita International Airport", city: "Tokyo", country: "JP" },
  { iataCode: "HND", name: "Haneda Airport", city: "Tokyo", country: "JP" },
  { iataCode: "ICN", name: "Incheon International Airport", city: "Seoul", country: "KR" },
  { iataCode: "SIN", name: "Singapore Changi Airport", city: "Singapore", country: "SG" },
  { iataCode: "BKK", name: "Suvarnabhumi Airport", city: "Bangkok", country: "TH" },
  { iataCode: "SYD", name: "Sydney Airport", city: "Sydney", country: "AU" },
  { iataCode: "MEL", name: "Melbourne Airport", city: "Melbourne", country: "AU" },
];

function normalizeForSearch(value) {
  return `${value || ""}`
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

export function searchAirportCatalog(keyword) {
  const query = normalizeForSearch(keyword).trim();
  if (query.length < 3) return [];

  return AIRPORTS.filter((item) => {
    const haystack = normalizeForSearch(
      `${item.iataCode} ${item.name} ${item.city} ${item.country}`
    );
    return haystack.includes(query);
  })
    .slice(0, 8)
    .map((item) => ({
      id: item.iataCode,
      iataCode: item.iataCode,
      name: item.name,
      city: item.city,
      country: item.country,
      subtitle: [item.city, item.country].filter(Boolean).join(", "),
    }));
}
